package ;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using tink.CoreApi;
using tink.MacroApi;

class Types extends Base {
  function type(c:ComplexType)
    return c.toType().sure();
    
  function resolve(type:String)
    return Context.getType(type);
    
  inline function assertSuccess<S, F>(o:Outcome<S, F>)
    assertTrue(o.isSuccess());
    
  inline function assertFailure<S, F>(o:Outcome<S, F>)
    assertFalse(o.isSuccess());
    
  function testIs() {
    assertSuccess(resolve('Int').isSubTypeOf(resolve('Float')));
    assertFailure(resolve('Float').isSubTypeOf(resolve('Int')));
  }  
  
  function testFields() {
    var expected = type(macro : Void -> Iterator<Arrayish>),
      iterator = type(macro : haxe.ds.StringMap<Arrayish>).getFields(true).sure().filter(function (c) return c.name == 'iterator')[0];
    
    assertSuccess(iterator.type.isSubTypeOf(expected));
    assertSuccess(expected.isSubTypeOf(iterator.type));
  }
  
  function testConvert() {
    assertSuccess((macro : Int).toType());
    assertFailure((macro : Tni).toType());
    function blank()
      return type(MacroApi.pos().makeBlankType());
    
    var bool = type(macro : Bool);
    assertTrue(blank().isSubTypeOf(bool).isSuccess());
    assertTrue(bool.isSubTypeOf(blank()).isSuccess());
    
    MacroApi.pos().makeBlankType().toString();
  }

  function testExpr() {
    assertEquals('VarChar<255>', (macro : VarChar<255>).toType().sure().toComplex().toString());
  }

  function testToComplex() {
    assertEquals('String', Context.getType('String').toComplex().toString());
    assertEquals('tink.CoreApi.Noise', Context.getType('tink.CoreApi.Noise').toComplex().toString());
  }
  
  function testConst() {
    assertEquals(255.5, getParams((macro : VarChar<255.5>).toType().sure(), 0).asFloat());
    assertEquals(255, getParams((macro : VarChar<255>).toType().sure(), 0).asInt());
    assertEquals('foo', getParams((macro : VarChar<'foo'>).toType().sure(), 0).asString());
    // assertTrue(getParams((macro : VarChar<true>).toType().sure(), 0).asBool());
    // assertFalse(getParams((macro : VarChar<false>).toType().sure(), 0).asBool());
    assertEquals('haxe', getParams((macro : VarChar<~/haxe/i>).toType().sure(), 0).asRegExp().r);
    assertEquals('i', getParams((macro : VarChar<~/haxe/i>).toType().sure(), 0).asRegExp().opt);
  }
  
  function getParams(t:Type, i:Int) {
    return switch t {
      case TInst(_, v) | TType(_, v): v[i];
      case _: throw 'assert here';
    }
  }
}